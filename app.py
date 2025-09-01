import os
import streamlit as st

from dotenv import load_dotenv, dotenv_values
from openai import AzureOpenAI

if os.path.exists(".env"):
    load_dotenv(override=True)
    config = dotenv_values(".env")

azure_openai_endpoint = os.getenv("AZURE_OPENAI_ENDPOINT")
azure_openai_api_key = os.getenv("AZURE_OPENAI_API_KEY")
azure_openai_chat_completions_deployment_name = os.getenv("AZURE_OPENAI_CHAT_COMPLETIONS_DEPLOYMENT_NAME")

azure_search_service_endpoint = os.getenv("AZURE_SEARCH_SERVICE_ENDPOINT")
azure_search_service_admin_key = os.getenv("AZURE_SEARCH_SERVICE_ADMIN_KEY")
search_index_name = os.getenv("SEARCH_INDEX_NAME")

openai_client = AzureOpenAI(
    azure_endpoint=azure_openai_endpoint,
    api_key=azure_openai_api_key,
    api_version="2024-12-01-preview"
)

system_prompt = "You are a helpful assistant for an AI learner, providing concised and clear answers."

def response_with_RAG(query, system_prompt):
    response = openai_client.chat.completions.create(
        model=azure_openai_chat_completions_deployment_name,
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": query}
        ],
        extra_body={
            "data_sources": [
                {
                    "type": "azure_search",
                    "parameters": {
                        "endpoint": azure_search_service_endpoint,
                        "index_name": search_index_name,
                        "authentication": {
                            "type": "api_key",
                            "key": azure_search_service_admin_key,
                        }
                    }
                }
            ]
        }
    )
    return response.choices[0].message.content

def response_without_RAG(query, system_prompt):
    response = openai_client.chat.completions.create(
        model=azure_openai_chat_completions_deployment_name,
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": query}
        ]
    )
    return response.choices[0].message.content

# ------------------------------
# Modern UI with Custom Styling
# ------------------------------

# Custom CSS for modern theme
st.set_page_config(
    page_title="LLM vs RAG (Azure OpenAI + AI Search)", 
    layout="wide",
    initial_sidebar_state="collapsed"
)

# Inject custom CSS
st.markdown("""
<style>
    /* Modern gradient background */
    .main {
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        min-height: 100vh;
    }
    
    /* Custom styling for the main container */
    .block-container {
        background: rgba(255, 255, 255, 0.95);
        border-radius: 20px;
        padding: 2rem;
        margin: 1rem;
        box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
        backdrop-filter: blur(10px);
        color: #333; /* Ensure text is dark */
    }
    
    /* Modern title styling */
    .main-title {
        background: linear-gradient(45deg, #667eea, #764ba2);
        -webkit-background-clip: text;
        -webkit-text-fill-color: transparent;
        background-clip: text;
        font-size: 2.5rem;
        font-weight: 700;
        text-align: center;
        margin-bottom: 2rem;
        padding: 1rem;
        color: #333; /* Fallback color */
    }
    
    /* Enhanced input styling */
    .stTextInput > div > div > input {
        border-radius: 15px;
        border: 2px solid #e0e0e0;
        padding: 1rem;
        font-size: 1.1rem;
        transition: all 0.3s ease;
        background: rgba(255, 255, 255, 0.9);
        color: #333; /* Ensure input text is dark */
    }
    
    /* Fix input label text color */
    .stTextInput > label {
        color: #333 !important;
        font-weight: 600;
        font-size: 1.3rem !important;
    }
    
    /* Fix placeholder text color */
    .stTextInput > div > div > input::placeholder {
        color: #666 !important;
    }
    
    .stTextInput > div > div > input:focus {
        border-color: #667eea;
        box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
        transform: translateY(-2px);
    }
    
    /* Modern button styling */
    .stButton > button {
        border-radius: 15px;
        background: linear-gradient(45deg, #667eea, #764ba2);
        border: none;
        padding: 0.8rem 2rem;
        font-size: 1.1rem;
        font-weight: 600;
        color: white;
        transition: all 0.3s ease;
        box-shadow: 0 4px 15px rgba(102, 126, 234, 0.3);
    }
    
    .stButton > button:hover {
        transform: translateY(-2px);
        box-shadow: 0 8px 25px rgba(102, 126, 234, 0.4);
    }
    
    /* Card styling for results */
    .result-card {
        background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
        border-radius: 20px;
        padding: 1.5rem;
        margin: 1rem 0;
        box-shadow: 0 10px 30px rgba(0, 0, 0, 0.1);
        border: 1px solid rgba(255, 255, 255, 0.2);
        transition: all 0.3s ease;
        color: #333; /* Ensure card text is dark */
    }
    
    .result-card:hover {
        transform: translateY(-5px);
        box-shadow: 0 15px 40px rgba(0, 0, 0, 0.15);
    }
    
    /* Subheader styling */
    .subheader {
        background: linear-gradient(45deg, #667eea, #764ba2);
        color: white;
        padding: 0.6rem 1.2rem;
        border-radius: 15px;
        font-weight: 600;
        margin-bottom: 0.5rem;
        text-align: center;
        box-shadow: 0 4px 15px rgba(102, 126, 234, 0.3);
    }
    
    /* Spinner styling */
    .stSpinner > div {
        border-color: #667eea !important;
    }
    
    /* Error styling */
    .stAlert {
        border-radius: 15px;
        border: none;
        background: linear-gradient(45deg, #ff6b6b, #ee5a52);
        color: white;
    }
    
    /* Hide default Streamlit elements */
    #MainMenu {visibility: hidden;}
    footer {visibility: hidden;}
    header {visibility: hidden;}
    
    /* Responsive design */
    @media (max-width: 768px) {
        .main-title {
            font-size: 2rem;
        }
        .block-container {
            padding: 1rem;
            margin: 0.5rem;
        }
    }
    
    /* Ensure all text elements have proper contrast */
    .stMarkdown, .stText, .stWrite {
        color: #333 !important;
    }
    
    /* Ensure Streamlit elements have proper text color */
    .stMarkdown p, .stMarkdown h1, .stMarkdown h2, .stMarkdown h3, .stMarkdown h4, .stMarkdown h5, .stMarkdown h6 {
        color: #333 !important;
    }
</style>
""", unsafe_allow_html=True)

# Modern header with gradient title
st.markdown('<h1 class="main-title">🤖 LLM vs RAG — Azure OpenAI + Azure AI Search</h1>', unsafe_allow_html=True)

# Modern input section with better spacing
query = st.text_input(
    "Enter your question", 
    placeholder="Ask something about AI, machine learning, or any topic...",
    key="query_input"
)

# Modern button with better positioning
col1, col2, col3 = st.columns([1, 1, 1])
with col2:
    run = st.button("🚀 Generate Response", type="primary", use_container_width=True)

# Create columns and show titles immediately
col1, col2 = st.columns(2)

# Plain LLM (no retrieval) - Modern card
with col1:
    st.markdown('<h3 class="subheader">🧠 Plain LLM (No Retrieval)</h3>', unsafe_allow_html=True)
    
    if run and query.strip():
        try:
            with st.spinner("🤔 Thinking..."):
                plain_answer = response_without_RAG(query, system_prompt)
            st.markdown(f"<div style='background: rgba(255,255,255,0.8); padding: 1rem; border-radius: 10px; border-left: 4px solid #667eea;'>{plain_answer}</div>", unsafe_allow_html=True)
        except Exception as e:
            st.error(f"❌ Error: {e}")
    else:
        st.markdown('<div style="background: rgba(255,255,255,0.8); padding: 1rem; border-radius: 10px; border-left: 4px solid #667eea; color: #666; font-style: italic;">Enter a question and click "Generate Response" to see the LLM answer here...</div>', unsafe_allow_html=True)

# RAG (vector search -> prompt) - Modern card
with col2:
    st.markdown('<h3 class="subheader">🔍 RAG (With Azure AI Search)</h3>', unsafe_allow_html=True)
    
    if run and query.strip():
        try:
            with st.spinner("🔎 Searching & answering..."):
                rag_answer = response_with_RAG(query, system_prompt)
            st.markdown(f"<div style='background: rgba(255,255,255,0.8); padding: 1rem; border-radius: 10px; border-left: 4px solid #764ba2;'>{rag_answer}</div>", unsafe_allow_html=True)
        except Exception as e:
            st.error(f"❌ Error: {e}")
    else:
        st.markdown('<div style="background: rgba(255,255,255,0.8); padding: 1rem; border-radius: 10px; border-left: 4px solid #764ba2; color: #666; font-style: italic;">Enter a question and click "Generate Response" to see the RAG answer here...</div>', unsafe_allow_html=True)

# Add a modern footer
st.markdown("<br><br>", unsafe_allow_html=True)
st.markdown("""
<div style='text-align: center; color: #666; font-size: 0.9rem; padding: 1rem;'>
    <p>🚀 Powered by Azure OpenAI & Azure AI Search | Built with Streamlit</p>
</div>
""", unsafe_allow_html=True)